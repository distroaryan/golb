document.addEventListener('DOMContentLoaded', () => {
    // DOM Elements
    const nodesGrid = document.getElementById('nodesGrid');
    const statTotal = document.getElementById('statTotal');
    const statHealthy = document.getElementById('statHealthy');
    const statOffline = document.getElementById('statOffline');
    const refreshBtn = document.getElementById('refreshBtn');
    const sendTrafficBtn = document.getElementById('sendTrafficBtn');
    const algoName = document.getElementById('algoName');
    
    // Modal Elements
    const addNodeModal = document.getElementById('addNodeModal');
    const addNodeBtn = document.getElementById('addNodeBtn');
    const closeBtn = document.querySelector('.close-btn');
    const cancelModalBtn = document.getElementById('cancelModalBtn');
    const submitNodeBtn = document.getElementById('submitNodeBtn');
    const nodeUrlInput = document.getElementById('nodeUrl');

    // Toast Element
    const toast = document.getElementById('toast');

    let pollInterval;
    let serverHits = {};

    // Initialize
    fetchInfoData();
    fetchHealthData();
    startPolling();

    // Event Listeners
    sendTrafficBtn.addEventListener('click', handleSendTraffic);
    refreshBtn.addEventListener('click', () => {
        fetchHealthData();
        showToast('Refreshed data manually', 'success');
    });

    addNodeBtn.addEventListener('click', () => {
        addNodeModal.classList.add('show');
        nodeUrlInput.focus();
    });

    closeBtn.addEventListener('click', closeModal);
    cancelModalBtn.addEventListener('click', closeModal);

    // Close modal on outside click
    window.addEventListener('click', (e) => {
        if (e.target === addNodeModal) closeModal();
    });

    submitNodeBtn.addEventListener('click', handleAddNode);

    // Functions
    function closeModal() {
        addNodeModal.classList.remove('show');
        nodeUrlInput.value = '';
    }

    function showToast(message, type = 'success') {
        toast.textContent = message;
        toast.className = `toast show ${type}`;
        
        setTimeout(() => {
            toast.className = 'toast';
        }, 3000);
    }

    async function fetchInfoData() {
        try {
            const response = await fetch('/api/info');
            if (response.ok) {
                const data = await response.json();
                algoName.textContent = data.algorithm;
            }
        } catch (error) {
            console.error('Error fetching info:', error);
            algoName.textContent = 'Unknown';
        }
    }

    async function handleSendTraffic() {
        try {
            const response = await fetch('/');
            const text = await response.text();
            
            // Look for port in the response text like "http://localhost:8081"
            const match = text.match(/http:\/\/[a-zA-Z0-9.-]+:(\d+)/);
            if (match && match[1]) {
                const port = match[1];
                if (!serverHits[port]) {
                    serverHits[port] = 0;
                }
                serverHits[port]++;
                
                // Refresh list right away to show hits
                fetchHealthData(); 
                showToast(`Traffic routed to node on port ${port}`, 'success');
            } else {
                showToast('Sent traffic, but could not parse backend URL/port', 'error');
            }
        } catch (error) {
            console.error('Error sending traffic:', error);
            showToast('Failed to send traffic', 'error');
        }
    }

    async function fetchHealthData() {
        try {
            const response = await fetch('/api/health');
            if (!response.ok) throw new Error('Network response was not ok');
            
            const data = await response.json();
            renderDashboard(data);
        } catch (error) {
            console.error('Error fetching health data:', error);
            showToast('Lost connection to Loadex API', 'error');
        }
    }

    function renderDashboard(data) {
        if (!data) return;

        let total = 0;
        let healthy = 0;
        let offline = 0;
        
        nodesGrid.innerHTML = '';
        
        // Sort for consistent rendering
        const urls = Object.keys(data).sort();
        
        urls.forEach(url => {
            const isAlive = data[url];
            total++;
            if (isAlive) healthy++; else offline++;

            const statusClass = isAlive ? 'status-online' : 'status-offline';
            const statusTextClass = isAlive ? 'status-online-text' : 'status-offline-text';
            const statusText = isAlive ? 'Healthy' : 'Offline';
            
            // Extract port to match securely against the hit counter (docker hostnames differ from localhost)
            const portMatch = url.match(/:(\d+)\/?$/);
            const port = portMatch ? portMatch[1] : url;
            const hits = serverHits[port] || serverHits[url] || 0;

            const card = document.createElement('div');
            card.className = 'node-card';
            
            // Add subtle glow based on status
            card.style.borderLeft = `3px solid ${isAlive ? 'var(--success-color)' : 'var(--danger-color)'}`;

            card.innerHTML = `
                <div class="node-info">
                    <span class="node-url">${url}</span>
                    <span class="node-status-text ${statusTextClass}">${statusText}</span>
                </div>
                <div class="node-hits">Hits: ${hits}</div>
                <div class="status-indicator ${statusClass}"></div>
            `;
            
            nodesGrid.appendChild(card);
        });

        // Update stats
        statTotal.textContent = total;
        statHealthy.textContent = healthy;
        statOffline.textContent = offline;
    }

    async function handleAddNode() {
        const url = nodeUrlInput.value.trim();
        if (!url) {
            showToast('Please enter a valid URL', 'error');
            return;
        }

        // Basic URL validation
        try {
            new URL(url);
        } catch (e) {
            showToast('Invalid URL format (include http://)', 'error');
            return;
        }

        try {
            const response = await fetch(`/api/add?url=${encodeURIComponent(url)}`, {
                method: 'POST'
            });

            if (response.ok) {
                showToast(`Successfully added ${url}`);
                closeModal();
                fetchHealthData(); // Refresh immediately
            } else {
                showToast(`Failed to add server: ${response.statusText}`, 'error');
            }
        } catch (error) {
            showToast('Network error while adding node', 'error');
        }
    }

    function startPolling() {
        // Poll every 2 seconds
        pollInterval = setInterval(fetchHealthData, 2000);
    }
});
