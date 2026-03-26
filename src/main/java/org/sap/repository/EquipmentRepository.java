package org.sap.repository;

import org.sap.model.Equipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EquipmentRepository extends JpaRepository<Equipment, Long> {

    Optional<Equipment> findByEquipmentCode(String equipmentCode);

    List<Equipment> findByStatus(Equipment.EquipmentStatus status);

    List<Equipment> findByEquipmentType(Equipment.EquipmentType equipmentType);

    List<Equipment> findByCurrentProjectId(Long projectId);
}
