WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost,
        sc.unique_parts
    FROM 
        SupplierCost sc
    JOIN 
        supplier s ON sc.s_suppkey = s.s_suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCost)
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.order_value) AS total_spent
    FROM 
        customer c
    JOIN 
        OrderStats o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    hs.s_name,
    c.c_custkey,
    c.total_orders,
    c.total_spent
FROM 
    HighValueSuppliers hs
JOIN 
    CustomerOrderCounts c ON hs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerX' LIMIT 1) LIMIT 1)
WHERE 
    c.total_spent > 10000
ORDER BY 
    hs.total_cost DESC, c.total_spent DESC;
