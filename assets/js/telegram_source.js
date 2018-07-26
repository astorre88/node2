let TelegramSource = {
  init(socket) {
    let channel = socket.channel("telegram_source:lobby", {})
    channel.join()
    this.listenForChat(channel)
  },

  listenForChat(channel) {
    document.getElementById("message-form").addEventListener("submit", function(e) {
      e.preventDefault()

      let msg = document.getElementById("message").value

      channel.push("shout", {body: msg})

      document.getElementById("message").value = ""
    })

    channel.on("shout", payload => {
      let messageBox = document.getElementById("message-box")
      let messageBlock = document.createElement("p")

      messageBlock.insertAdjacentHTML('beforeend', payload.body)
      messageBox.appendChild(messageBlock)
    })
  }
}

export default TelegramSource
