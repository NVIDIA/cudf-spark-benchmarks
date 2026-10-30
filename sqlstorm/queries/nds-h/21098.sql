WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL
),
SupplierPartData AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey,
        ps.ps_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    coalesce(cos.total_orders, 0) AS num_orders,
    coalesce(cos.total_spent, 0) AS total_spent,
    CASE 
        WHEN cos.total_spent > 10000 THEN 'High Value' 
        WHEN cos.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    RANK() OVER (ORDER BY SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) DESC) AS return_rank,
    r.r_name AS region_name
FROM 
    customer c
LEFT JOIN 
    CustomerOrderSummary cos ON c.c_custkey = cos.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartData spd ON spd.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l
        WHERE l.l_discount > 0.1 AND l.l_tax < 0.05
    ) 
WHERE 
    r.r_comment IS NOT NULL
GROUP BY 
    c.c_custkey, c.c_name, r.r_name, cos.total_orders, cos.total_spent
HAVING 
    COUNT(DISTINCT o.o_orderkey) >= 5 
ORDER BY 
    customer_value DESC, num_orders DESC
LIMIT 20;
