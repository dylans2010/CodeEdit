import { ApolloServer } from '@apollo/server';
import { startStandaloneServer } from '@apollo/server/standalone';

const typeDefs = `#graphql
  type Query {
    hello: String
    service: String
  }
`;

const resolvers = {
  Query: {
    hello: () => 'Hello from {{PROJECT_NAME}} GraphQL!',
    service: () => '{{PROJECT_NAME}}'
  },
};

const server = new ApolloServer({ typeDefs, resolvers });
const { url } = await startStandaloneServer(server, { listen: { port: 4000 } });
console.log(`🚀 GraphQL server ready at: ${url}`);
