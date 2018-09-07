module.exports = {
    getTransformModulePath() {
        return require.resolve("./fixConnect");
    },
    getSourceExts() {
        return ['ts', 'tsx']
    }
};