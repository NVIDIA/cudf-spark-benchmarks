
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_nationkey
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.part_count,
        ss.total_supply_value
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStats)
)
SELECT 
    co.c_custkey,
    co.order_count,
    co.total_spent,
    hs.s_name AS high_value_supplier,
    hs.part_count
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueSuppliers hs ON co.c_custkey IN 
    (SELECT 
        o.o_custkey 
     FROM 
        orders o 
     JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE 
        l.l_discount > 0.05 AND l.l_returnflag = 'N')
WHERE 
    co.spending_rank <= 5
ORDER BY 
    co.total_spent DESC, co.c_custkey ASC;
