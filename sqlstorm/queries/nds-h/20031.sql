
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
OrderItemStats AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_amount,
        COUNT(*) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey
)
SELECT 
    hvp.p_partkey,
    hvp.p_name,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(oi.total_amount) AS avg_order_amount,
    SUM(oi.total_items) AS total_order_items,
    CASE 
        WHEN COUNT(DISTINCT r.s_suppkey) > 1 THEN 'Multiple Suppliers' 
        ELSE 'Single Supplier' 
    END AS supplier_status
FROM 
    HighValueParts hvp
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1 
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = hvp.p_partkey
LEFT JOIN 
    orders o ON o.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
        ORDER BY c.c_acctbal DESC
        LIMIT 1
    )
LEFT JOIN 
    OrderItemStats oi ON oi.o_orderkey = o.o_orderkey
WHERE 
    hvp.total_supply_cost > 10000
GROUP BY 
    hvp.p_partkey, 
    hvp.p_name, 
    r.s_name
HAVING 
    SUM(oi.total_amount) / NULLIF(COUNT(DISTINCT o.o_orderkey), 0) > 500
ORDER BY 
    hvp.p_partkey DESC, 
    total_order_items DESC;
