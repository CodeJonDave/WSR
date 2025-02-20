<template>
  <div id="app">
    <header>
      <!--Global header (can conditionally show based on portal) -->
    </header>

    <main>
      <router-view></router-view>
      <!--Routes will be rendered here -->
    </main>

    <footer>
      <!-- Global footer -->
    </footer>
  </div>
</template>

<script>
export default {
  name: "App",
};
</script>

<style>
/* Global styles*/
</style>
