package healthchecker

import (
	"context"
	"net/http"
	"net/url"
	"sync"
	"time"

	"github.com/distroaryan/golb"
	"github.com/distroaryan/golb/logger"
)

type HealthChecker struct {
	interval   time.Duration
	serversURL []*url.URL
	lb         golb.LoadBalancer
}

func NewHealthChecker(interval time.Duration, servers []*url.URL, lb golb.LoadBalancer) *HealthChecker {
	return &HealthChecker{
		interval:   interval,
		serversURL: servers,
		lb:  lb,
	}
}

func (hc *HealthChecker) Start(ctx context.Context) {
	ticker := time.NewTicker(hc.interval)
	go func() {
		defer func() {
			ticker.Stop()
			if logger.Log != nil {
				logger.Log.Info("Health Checker stopped")
			}
		}()
		for {
			select {
			case <-ticker.C:
				if err := hc.updateHealthMap(); err != nil {
					if logger.Log != nil {
						logger.Log.Error("Health check error", "error", err)
					}
				}
			case <-ctx.Done():
				return
			}
		}
	}()
}

func (hc *HealthChecker) updateHealthMap() error {
	var wg sync.WaitGroup
	for _, url := range hc.serversURL {
		wg.Add(1)
		go func() {
			defer wg.Done()
			healthCheck := pingServer(url)
			hc.lb.UpdateHealth(url.String(), healthCheck)
		}()
	}
	wg.Wait()
	logger.Log.Info("Health Check completed")
	return nil
}

func pingServer(url *url.URL) bool {
	resp, err := http.Get(url.String() + "/health")
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode == http.StatusOK
}
