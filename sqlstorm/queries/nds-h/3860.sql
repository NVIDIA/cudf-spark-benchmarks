
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    p.p_name AS product_name,
    sp.total_avail_qty,
    sp.total_supply_cost,
    CASE 
        WHEN co.total_orders > 0 THEN co.total_spent / co.total_orders 
        ELSE NULL 
    END AS avg_spent_per_order,
    r.r_name AS region_name
FROM 
    CustomerOrderStats co
LEFT JOIN 
    nation n ON co.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    PartSupplierInfo p ON co.c_custkey = p.p_partkey
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
WHERE 
    (co.total_orders IS NULL OR co.total_orders > 5)
ORDER BY 
    avg_spent_per_order DESC
LIMIT 100;
