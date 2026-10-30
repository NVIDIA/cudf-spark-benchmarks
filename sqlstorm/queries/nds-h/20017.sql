
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000.00
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        AVG(c.c_acctbal) AS avg_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        AVG(c.c_acctbal) > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        ps.p_partkey,
        hvs.total_supply_value,
        c.total_spent,
        ns.avg_acctbal,
        ns.supplier_count
    FROM 
        RankedParts ps
    JOIN 
        HighValueSuppliers hvs ON ps.p_partkey = hvs.ps_suppkey
    LEFT JOIN 
        CustomerOrders c ON c.c_custkey = (SELECT o.o_custkey FROM orders o ORDER BY o.o_totalprice DESC LIMIT 1)
    LEFT JOIN 
        NationSummary ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n ORDER BY n.n_nationkey DESC LIMIT 1)
    JOIN 
        region r ON r.r_regionkey = ns.n_nationkey
    WHERE 
        (ps.price_rank <= 5 OR hvs.total_supply_value IS NOT NULL)
        AND r.r_name IS NOT NULL
)
SELECT 
    region_name,
    COUNT(DISTINCT p_partkey) AS part_count,
    SUM(total_supply_value) AS total_supply,
    AVG(total_spent) AS avg_spent,
    COALESCE(MAX(avg_acctbal), 0) AS max_avg_acctbal,
    COUNT(DISTINCT supplier_count) AS active_suppliers
FROM 
    FinalReport
GROUP BY 
    region_name
HAVING 
    SUM(total_supply_value) > (SELECT AVG(total_supply_value) FROM HighValueSuppliers)
ORDER BY 
    region_name ASC, part_count DESC;
