package grpc

import (
	"context"

	"github.com/khulnasoft-lab/tracker/pkg/version"
	pb "github.com/khulnasoft-lab/tracker/types/api/v1beta1"
)

type TrackerService struct {
	pb.UnimplementedTrackerServiceServer
}

func (s *TrackerService) GetVersion(ctx context.Context, in *pb.GetVersionRequest) (*pb.GetVersionResponse, error) {
	return &pb.GetVersionResponse{Version: version.GetVersion()}, nil
}
