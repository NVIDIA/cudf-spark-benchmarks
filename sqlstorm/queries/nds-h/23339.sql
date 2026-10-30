
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)

SELECT 
    r.p_partkey,
    r.p_name,
    COALESCE(sa.total_avail_qty, 0) AS available_quantity,
    COALESCE(sa.max_supply_cost, 0) AS highest_supply_cost,
    COALESCE(o.o_totalprice, 0) AS order_total,
    CASE 
        WHEN r.rn <= 3 THEN 'Top 3'
        ELSE 'Others'
    END AS ranking,
    CASE 
        WHEN COUNT(DISTINCT f.s_suppkey) > 2 THEN 'Multiple Suppliers'
        ELSE 'Single Supplier or None'
    END AS supplier_status
FROM 
    RankedParts r
LEFT JOIN 
    SupplierAvailability sa ON r.p_partkey = sa.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = r.p_partkey
LEFT JOIN 
    CustomerOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    FilteredSuppliers f ON f.part_count > 0 
WHERE 
    r.rn <= 10
GROUP BY 
    r.p_partkey, r.p_name, sa.total_avail_qty, sa.max_supply_cost, o.o_totalprice, r.rn
ORDER BY 
    available_quantity DESC, order_total DESC
LIMIT 100;
