import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const EventOrganizerModule = buildModule("EventOrganizerModule", (m) => {
  
  const eventManage = m.contract("EventOrganizer");

  return { eventManage };
});

export default EventOrganizerModule;