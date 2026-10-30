WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY s_name ORDER BY total_supply_value DESC) AS supply_rank
    FROM 
        SupplierStats
)
SELECT 
    cs.c_name,
    cs.total_order_value,
    cs.order_count,
    rs.s_name AS supplier_name,
    rs.total_supply_value,
    rs.avg_supply_cost,
    rs.part_count
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
WHERE 
    (cs.total_order_value IS NOT NULL AND rs.total_supply_value IS NOT NULL)
    OR (cs.total_order_value IS NULL AND rs.total_supply_value IS NULL)
ORDER BY 
    cs.total_order_value DESC NULLS LAST, 
    rs.total_supply_value DESC NULLS LAST;
