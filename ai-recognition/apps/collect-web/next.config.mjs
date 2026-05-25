/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ["@howtune/ml"],
  serverExternalPackages: ["@tensorflow/tfjs-node"]
};

export default nextConfig;

