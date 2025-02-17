export const environmentsList = [
  {
    name: 'DEV',
    size: 1,
    id: 7,
    state: 'available',
    external_url: null,
    environment_type: null,
    last_deployment: null,
    has_stop_action: false,
    environment_path: '/root/review-app/environments/7',
    stop_path: '/root/review-app/environments/7/stop',
    created_at: '2017-01-31T10:53:46.894Z',
    updated_at: '2017-01-31T10:53:46.894Z',
    project_path: '/root/review-app',
    rollout_status: {},
  },
  {
    folderName: 'build',
    size: 5,
    id: 12,
    name: 'build/update-README',
    state: 'available',
    external_url: null,
    environment_type: 'build',
    last_deployment: null,
    has_stop_action: false,
    environment_path: '/root/review-app/environments/12',
    stop_path: '/root/review-app/environments/12/stop',
    created_at: '2017-02-01T19:42:18.400Z',
    updated_at: '2017-02-01T19:42:18.400Z',
    project_path: '/root/review-app',
    rollout_status: {},
  },
];

export const serverData = [
  {
    name: 'DEV',
    size: 1,
    latest: {
      id: 7,
      name: 'DEV',
      state: 'available',
      external_url: null,
      environment_type: null,
      last_deployment: null,
      has_stop_action: false,
      environment_path: '/root/review-app/environments/7',
      stop_path: '/root/review-app/environments/7/stop',
      created_at: '2017-01-31T10:53:46.894Z',
      updated_at: '2017-01-31T10:53:46.894Z',
      rollout_status: {},
    },
  },
  {
    name: 'build',
    size: 5,
    latest: {
      id: 12,
      name: 'build/update-README',
      state: 'available',
      external_url: null,
      environment_type: 'build',
      last_deployment: null,
      has_stop_action: false,
      environment_path: '/root/review-app/environments/12',
      stop_path: '/root/review-app/environments/12/stop',
      created_at: '2017-02-01T19:42:18.400Z',
      updated_at: '2017-02-01T19:42:18.400Z',
    },
  },
  {
    name: 'build',
    size: 1,
    latest: {
      id: 12,
      name: 'build/update-README',
      state: 'available',
      external_url: null,
      environment_type: 'build',
      last_deployment: null,
      has_stop_action: false,
      environment_path: '/root/review-app/environments/12',
      stop_path: '/root/review-app/environments/12/stop',
      created_at: '2017-02-01T19:42:18.400Z',
      updated_at: '2017-02-01T19:42:18.400Z',
    },
  },
];

export const deployBoardMockData = {
  instances: [
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2334 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2335 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2336 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2337 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2338 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2339 Finished', pod_name: 'production-tanuki-1' },
    { status: 'finished', tooltip: 'tanuki-2340 Finished', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2341 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2342 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'deploying', tooltip: 'tanuki-2343 Deploying', pod_name: 'production-tanuki-1' },
    { status: 'failed', tooltip: 'tanuki-2344 Failed', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2345 Ready', pod_name: 'production-tanuki-1' },
    { status: 'ready', tooltip: 'tanuki-2346 Ready', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2348 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2349 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2350 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'preparing', tooltip: 'tanuki-2353 Preparing', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2354 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2355 Waiting', pod_name: 'production-tanuki-1' },
    { status: 'waiting', tooltip: 'tanuki-2356 Waiting', pod_name: 'production-tanuki-1' },
  ],
  abort_url: 'url',
  rollback_url: 'url',
  completion: 100,
  status: 'found',
};

export const folder = {
  folderName: 'build',
  size: 5,
  id: 12,
  name: 'build/update-README',
  state: 'available',
  external_url: null,
  environment_type: 'build',
  last_deployment: null,
  has_stop_action: false,
  environment_path: '/root/review-app/environments/12',
  stop_path: '/root/review-app/environments/12/stop',
  created_at: '2017-02-01T19:42:18.400Z',
  updated_at: '2017-02-01T19:42:18.400Z',
  rollout_status: {},
  project_path: '/root/review-app',
};
