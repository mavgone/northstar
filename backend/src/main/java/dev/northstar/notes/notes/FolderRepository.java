package dev.northstar.notes.notes;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FolderRepository extends JpaRepository<FolderEntity, UUID> {
  List<FolderEntity> findByOwnerIdOrderByNameAsc(UUID ownerId);

  Optional<FolderEntity> findByIdAndOwnerId(UUID id, UUID ownerId);
}
