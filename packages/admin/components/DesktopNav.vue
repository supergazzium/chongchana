<template>
  <aside>
    <div class="content-area">
      <div class="branding">
        <!-- <h1 v-html="`${_brandname} CMS`" class="_fs-5"></h1>
        <p class="_fs-7 _fw-500 _mgt-4px">Powered by Anotter.</p> -->
        <img src="~assets/images/logo-white.svg" alt="" />
      </div>

      <div class="content">
        <ul>
          <li
            v-for="(val, i) in _navLinks"
            :key="`navLink-${i}`"
            :class="{
              '-w-sub': val.submenu && $route.path.includes(val.keyword),
            }"
          >
            <nuxt-link class="link-w-icon" :to="val.path" v-if="!val.submenu">
              <div class="link-icon">
                <i class="fas" :class="[`fa-${val.icon}`]"></i>
              </div>
              <span v-html="val.label"></span>
            </nuxt-link>

            <div v-else>
              <h5 class="_mgt-16px _mgbt-16px" v-html="val.label"></h5>
              <ul>
                <li v-for="(sub, s) in val.submenu" :key="`submenu-${s}`">
                  <nuxt-link class="link-w-icon" :to="sub.path">
                    <div class="link-icon">
                      <i class="fas" :class="[`fa-${sub.icon}`]"></i>
                    </div>
                    <span v-html="sub.label"></span>
                  </nuxt-link>
                </li>
              </ul>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <div class="footer">
      <div class="link-w-icon" @click="signout">
        <div class="link-icon">
          <i class="fas fa-door-open"></i>
        </div>
        <span>ออกจากระบบ</span>
      </div>
    </div>
  </aside>
</template>

<script>
export default {
  computed: {
    _navLinks() {
      if (
        this.$auth.user &&
        this.$auth.user.role.type === "staff_atk"
      ) {
        return this.$store.state.staffATKMenus;
      }
      return this.$store.state.navLinks;
    },
    _brandname() {
      return this.$store.state.brandname;
    },
  },
  methods: {
    async signout() {
      await this.$auth.logout();
      this.__showToast({
        type: "success",
        title: "Signout Successfully",
        message: "Redirecting you to signin",
      });
    },
  },
};
</script>

<style lang="scss" scoped>
@import "~assets/styles/variables";

$bg-color: #0a2e33;
$border-color: #061b1e;

aside {
  flex: 0 0 250px;
  background: $bg-color;
  // border-right: 1px solid $card-border-color;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  overflow: hidden;

  .content-area {
    flex: 1;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    position: relative;

    .branding {
      flex: 0 0 69px;
      padding: 16px 26px;
      border-bottom: 1px solid $border-color;

      img {
        width: 100px;
        height: auto;
        margin-left: auto;
        margin-right: auto;
        display: block;
      }
    }

    .content {
      flex: 1;
      padding: 12px 0 48px 0;
      overflow: hidden;
      overflow-y: scroll;
      position: relative;

      ul {
        list-style: none;
        margin: 0;

        li {
          margin-top: 8px;
          margin-bottom: 8px;
          padding-left: 26px;
          padding-right: 26px;
          color: #fff;
          cursor: pointer;
          font-weight: bold;
          font-size: 1rem;

          a {
            padding: 12px 14px;
            color: #fff;
            position: relative;
            margin-left: -12px;
            opacity: 0.4;
            transition: opacity 0.3s;

            &.nuxt-link-active,
            &:hover {
              opacity: 1;
              transition: opacity 0.3s;
              // background: rgba($primary-color, .15);
              // border-radius: 5px;
              // color: $primary-color;

              // i {
              //   color: $primary-color;
              // }
            }
          }

          h5 {
            color: lighten($primary-color, 13%);
            text-transform: uppercase;
            letter-spacing: 1px;
            font-size: 12px;
          }

          li {
            padding-left: 0;
            padding-right: 0;
          }

          &:last-of-type {
            margin-bottom: 0;
          }
        }
      }
    }
  }

  .footer {
    flex: 0 0 54px;
    // border-top: 1px solid darken($primary-color, 25%);
    border-top: 1px solid $border-color;
    padding-top: 26px;
    padding-bottom: 26px;

    > div {
      color: #fff;
      font-weight: bold;
      justify-content: center;
      transition: 0.3s;
      cursor: pointer;

      &:hover {
        opacity: 1;
        transition: 0.3s;
      }
    }
  }

  .link-w-icon {
    color: inherit;
    text-decoration: none;
    display: flex;
    align-items: center;

    .link-icon {
      width: 24px;
      margin-left: -4px;
      text-align: center;
      margin-right: 12px;
      color: rgba(255, 255, 255, 0.7);
    }
  }
}
</style>
