WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        p.p_size, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%plastic%')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        ss.available_parts, 
        ss.total_supply_cost, 
        ss.avg_account_balance,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM SupplierStats ss
    WHERE ss.available_parts > 5
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost
FROM RankedParts rp
JOIN TopSuppliers ts ON ts.available_parts > 0
WHERE rp.rank <= 10
ORDER BY rp.p_retailprice DESC, ts.total_supply_cost ASC;
