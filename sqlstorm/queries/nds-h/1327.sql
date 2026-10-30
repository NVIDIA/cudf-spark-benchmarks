WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighCostParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        sc.total_supply_cost
    FROM 
        part p
    JOIN 
        SupplierCost sc ON p.p_partkey = sc.ps_partkey
    WHERE 
        sc.total_supply_cost > 1000.00 
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.order_count,
    hcp.p_name,
    hcp.p_brand,
    r.r_name,
    CASE 
        WHEN co.order_count > 5 THEN 'High'
        WHEN co.order_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS order_priority,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem l ON co.order_count = l.l_orderkey
JOIN 
    HighCostParts hcp ON l.l_partkey = hcp.p_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    hcp.total_supply_cost IS NOT NULL 
GROUP BY 
    co.c_name, co.order_count, hcp.p_name, hcp.p_brand, r.r_name
HAVING 
    AVG(l.l_discount) > 0.05 
ORDER BY 
    order_priority DESC, total_orders DESC;