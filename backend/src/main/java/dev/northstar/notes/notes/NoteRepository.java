package dev.northstar.notes.notes;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
@Repository
public interface NoteRepository extends JpaRepository<NoteEntity, UUID> {
  List<NoteEntity> findByOwnerIdOrderByUpdatedAtDesc(UUID ownerId);
  Optional<NoteEntity> findByIdAndOwnerId(UUID id, UUID ownerId);
  List<NoteEntity> findByOwnerIdAndFolderId(UUID ownerId, UUID folderId);
  @Modifying
  @Query("UPDATE NoteEntity n SET n.folderId = :toId WHERE n.ownerId = :ownerId AND n.folderId = :fromId")
  void moveNotesToFolder(@Param("ownerId") UUID ownerId, @Param("fromId") UUID fromId, @Param("toId") UUID toId);
}
