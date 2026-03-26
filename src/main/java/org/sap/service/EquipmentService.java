package org.sap.service;

import lombok.RequiredArgsConstructor;
import org.sap.model.Equipment;
import org.sap.model.Project;
import org.sap.repository.EquipmentRepository;
import org.sap.repository.ProjectRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EquipmentService {

    private final EquipmentRepository equipmentRepository;
    private final ProjectRepository projectRepository;

    public List<Equipment> findAll() {
        return equipmentRepository.findAll();
    }

    public Optional<Equipment> findById(Long id) {
        return equipmentRepository.findById(id);
    }

    public List<Equipment> findByStatus(Equipment.EquipmentStatus status) {
        return equipmentRepository.findByStatus(status);
    }

    public List<Equipment> findByProjectId(Long projectId) {
        return equipmentRepository.findByCurrentProjectId(projectId);
    }

    @Transactional
    public Equipment save(Equipment equipment) {
        return equipmentRepository.save(equipment);
    }

    @Transactional
    public Equipment assignToProject(Long equipmentId, Long projectId) {
        Equipment equipment = equipmentRepository.findById(equipmentId)
                .orElseThrow(() -> new IllegalArgumentException("장비를 찾을 수 없습니다: " + equipmentId));

        if (projectId != null) {
            Project project = projectRepository.findById(projectId)
                    .orElseThrow(() -> new IllegalArgumentException("프로젝트를 찾을 수 없습니다: " + projectId));
            equipment.setCurrentProject(project);
            equipment.setStatus(Equipment.EquipmentStatus.IN_USE);
        } else {
            equipment.setCurrentProject(null);
            equipment.setStatus(Equipment.EquipmentStatus.AVAILABLE);
        }

        return equipmentRepository.save(equipment);
    }

    @Transactional
    public Equipment update(Long id, Equipment updated) {
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("장비를 찾을 수 없습니다: " + id));

        equipment.setEquipmentName(updated.getEquipmentName());
        equipment.setEquipmentType(updated.getEquipmentType());
        equipment.setModel(updated.getModel());
        equipment.setManufacturer(updated.getManufacturer());
        equipment.setRegistrationNumber(updated.getRegistrationNumber());
        equipment.setStatus(updated.getStatus());
        equipment.setIsRented(updated.getIsRented());
        equipment.setRentalCostPerDay(updated.getRentalCostPerDay());
        equipment.setNextMaintenanceDate(updated.getNextMaintenanceDate());
        equipment.setTotalOperatingHours(updated.getTotalOperatingHours());

        return equipmentRepository.save(equipment);
    }

    @Transactional
    public void delete(Long id) {
        equipmentRepository.deleteById(id);
    }
}
