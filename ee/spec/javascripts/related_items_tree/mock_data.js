export const mockInitialConfig = {
  epicsEndpoint: 'http://test.host',
  issuesEndpoint: 'http://test.host',
  autoCompleteEpics: true,
  autoCompleteIssues: false,
};

export const mockParentItem = {
  iid: 1,
  fullPath: 'gitlab-org',
  title: 'Some sample epic',
  reference: 'gitlab-org&1',
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
};

export const mockEpic1 = {
  id: '4',
  iid: '4',
  title: 'Quo ea ipsa enim perferendis at omnis officia.',
  state: 'opened',
  webPath: '/groups/gitlab-org/-/epics/4',
  reference: '&4',
  relationPath: '/groups/gitlab-org/-/epics/1/links/4',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: null,
  hasChildren: true,
  hasIssues: true,
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
};

export const mockEpic2 = {
  id: '3',
  iid: '3',
  title: 'A nisi mollitia explicabo quam soluta dolor hic.',
  state: 'closed',
  webPath: '/groups/gitlab-org/-/epics/3',
  reference: '&3',
  relationPath: '/groups/gitlab-org/-/epics/1/links/3',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: '2019-04-26T06:51:22Z',
  hasChildren: false,
  hasIssues: false,
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
};

export const mockIssue1 = {
  iid: '8',
  title: 'Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.',
  closedAt: null,
  state: 'opened',
  createdAt: '2019-02-18T14:06:41Z',
  confidential: true,
  dueDate: '2019-06-14',
  weight: 5,
  webPath: '/gitlab-org/gitlab-shell/issues/8',
  reference: 'gitlab-org/gitlab-shell#8',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/10',
  assignees: {
    edges: [
      {
        node: {
          webUrl: 'http://127.0.0.1:3001/root',
          name: 'Administrator',
          username: 'root',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
      },
    ],
  },
  milestone: {
    title: 'v4.0',
    startDate: '2019-02-01',
    dueDate: '2019-06-30',
  },
};

export const mockIssue2 = {
  iid: '33',
  title: 'Dismiss Cipher with no integrity',
  closedAt: null,
  state: 'opened',
  createdAt: '2019-02-18T14:13:05Z',
  confidential: false,
  dueDate: null,
  weight: null,
  webPath: '/gitlab-org/gitlab-shell/issues/33',
  reference: 'gitlab-org/gitlab-shell#33',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/27',
  assignees: {
    edges: [],
  },
  milestone: null,
};

export const mockEpics = [mockEpic1, mockEpic2];

export const mockIssues = [mockIssue1, mockIssue2];

export const mockQueryResponse = {
  data: {
    group: {
      id: 1,
      path: 'gitlab-org',
      fullPath: 'gitlab-org',
      epic: {
        id: 1,
        iid: 1,
        title: 'Foo bar',
        webPath: '/groups/gitlab-org/-/epics/1',
        userPermissions: {
          adminEpic: true,
          createEpic: true,
        },
        children: {
          edges: [
            {
              node: mockEpic1,
            },
            {
              node: mockEpic2,
            },
          ],
          pageInfo: {
            endCursor: 'abc',
            hasNextPage: true,
          },
        },
        issues: {
          edges: [
            {
              node: mockIssue1,
            },
            {
              node: mockIssue2,
            },
          ],
          pageInfo: {
            endCursor: 'def',
            hasNextPage: true,
          },
        },
      },
    },
  },
};
