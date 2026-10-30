WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_retailprice, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_retailprice
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopNationalSuppliers AS (
    SELECT 
        ns.n_name,
        SUM(ss.total_parts_supplied) AS total_parts,
        AVG(ss.avg_acctbal) AS avg_acctbal
    FROM SupplierStats ss
    JOIN nation ns ON ss.s_nationkey = ns.n_nationkey
    GROUP BY ns.n_name
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.total_supply_cost, 
    tns.n_name, 
    tns.total_parts, 
    tns.avg_acctbal
FROM RankedParts rp
JOIN TopNationalSuppliers tns ON rp.rnk <= 3 
ORDER BY rp.total_supply_cost DESC, tns.n_name ASC;
