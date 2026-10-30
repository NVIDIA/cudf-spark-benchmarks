WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s_acctbal, 
           CONCAT(s.s_name, ' - ', s.s_address, ' (', s.s_acctbal, ')') AS SupplierInfo
    FROM supplier s
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, 
           CONCAT(p.p_name, ' [', p.p_mfgr, ']') AS PartDescription, 
           COUNT(ps.ps_partkey) AS SupplierCount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
), CombinedData AS (
    SELECT s.SupplierInfo, pd.PartDescription, os.TotalRevenue
    FROM SupplierDetails s
    JOIN PartDetails pd ON s.s_suppkey = pd.SupplierCount
    JOIN OrderSummary os ON os.TotalRevenue = pd.SupplierCount
)
SELECT SupplierInfo, PartDescription, COALESCE(SUM(TotalRevenue), 0) AS TotalRevenue 
FROM CombinedData
GROUP BY SupplierInfo, PartDescription
ORDER BY TotalRevenue DESC, SupplierInfo ASC;
