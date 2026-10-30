
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_availqty,
        ss.avg_supplycost,
        ss.part_count,
        ROW_NUMBER() OVER (PARTITION BY ss.part_count ORDER BY ss.total_availqty DESC) AS rn
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_availqty > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS order_value
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
    HAVING 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 1000
)
SELECT 
    ts.s_name,
    ts.total_availqty,
    ts.avg_supplycost,
    co.c_name,
    co.order_count,
    co.total_spent,
    hvo.order_value
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey 
LEFT JOIN 
    HighValueOrders hvo ON co.order_count = hvo.l_orderkey
WHERE 
    ts.rn <= 5 AND 
    (co.order_count > 5 OR co.total_spent IS NULL)
ORDER BY 
    ts.total_availqty DESC, co.total_spent DESC;
