import Data.Functor.Both as Both
import Data.List
hunkLength hunk = mconcat $ (changeLength <$> changes hunk) <> (rowIncrement <$> trailingContext hunk)
changeLength change = mconcat $ (rowIncrement <$> context change) <> (rowIncrement <$> contents change)
-- | The increment the given row implies for line numbering.
rowIncrement :: Row a -> Both (Sum Int)
rowIncrement = fmap lineIncrement
showHunk blobs hunk = if last sourceHunk /= '\n'
                      then sourceHunk ++ "\n\\\\ No newline at end of file\n"
                      else sourceHunk
        sourceHunk = header blobs hunk ++ concat (showChange sources <$> changes hunk) ++ showLines (snd sources) ' ' (snd <$> trailingContext hunk)
showChange sources change = showLines (snd sources) ' ' (snd <$> context change) ++ deleted ++ inserted
  where (deleted, inserted) = runBoth $ pure showLines <*> sources <*> Both ('-', '+') <*> Both.unzip (contents change)
showLine source line | isEmpty line = Nothing
                     | otherwise = Just . toString . (`slice` source) . unionRanges $ getRange <$> unLine line
hunks _ blobs | Both (True, True) <- null . source <$> blobs = [Hunk { offset = mempty, changes = [], trailingContext = [] }]
hunks diff blobs = hunksInRows (Both (1, 1)) $ fmap (fmap Prelude.fst) <$> splitDiffByLines (source <$> blobs) diff
  Just (change, afterChanges) -> Just (start <> mconcat (rowIncrement <$> skippedContext), change, afterChanges)
rowHasChanges lines = or (lineHasChanges <$> lines)