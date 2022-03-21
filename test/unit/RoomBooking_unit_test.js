const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("RoomBooking Unit Tests", async function () {
      let roomBooking,
        accounts = []

      beforeEach(async () => {
        await deployments.fixture(["booking"])

        roomBooking = await ethers.getContract("RoomBooking")

        // set accounts and mint 1000 tokens to each account
        const signers = await ethers.getSigners()
        for (let i = 0; i < 3; i++) {
          accounts.push(signers[i])
        }
      })

      it("Should successfully book a room", async () => {
        await roomBooking.connect(accounts[0]).bookRoom(1, 1)
        const room = await roomBooking.rooms(1)

        assert.equal(await roomBooking.getUserRoom(accounts[0].address), 1)
        assert.equal(room.userCount, 1)
        assert.equal(room.company, 1)
      })

      it("Can book a same room", async () => {
        await roomBooking.connect(accounts[0]).bookRoom(1, 1)
        await roomBooking.connect(accounts[1]).bookRoom(1, 1)

        const roomUsers = await roomBooking.getRoomUsers(1)

        assert.equal(roomUsers[0], accounts[0].address)
        assert.equal(roomUsers[1], accounts[1].address)
      })

      it("Should be not able to book another company's room", async () => {
        await roomBooking.connect(accounts[0]).bookRoom(1, 1)
        await expect(roomBooking.connect(accounts[1]).bookRoom(1, 0)).to.be.revertedWith(
          "Another company owned the room"
        )

        const room = await roomBooking.rooms(1)
        assert.equal(room.userCount, 1)
      })

      it("Should be not able to book 2 rooms together", async () => {
        await roomBooking.connect(accounts[0]).bookRoom(1, 1)
        await expect(roomBooking.connect(accounts[0]).bookRoom(2, 1)).to.be.revertedWith(
          "Already booked a room"
        )

        const firstRoom = await roomBooking.rooms(1)
        const secondRoom = await roomBooking.rooms(2)
        assert.equal(firstRoom.userCount, 1)
        assert.equal(secondRoom.userCount, 0)
      })

      it("Should be able to cancel reservation", async () => {
        await roomBooking.connect(accounts[0]).bookRoom(1, 1)
        await roomBooking.connect(accounts[1]).bookRoom(1, 1)

        const roomFirstStage = await roomBooking.rooms(1)
        assert.equal(roomFirstStage.userCount, 2)

        await roomBooking.connect(accounts[0]).cancelReservation()
        const roomSecondStage = await roomBooking.rooms(1)
        assert.equal(roomSecondStage.userCount, 1)
      })
    })
