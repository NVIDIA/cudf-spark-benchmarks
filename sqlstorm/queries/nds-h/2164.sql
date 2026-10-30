
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank,
        o.o_custkey,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
), 
PartStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    ps.p_name AS part_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice AS order_total_price,
    cs.total_orders AS customer_order_count,
    cs.total_spent AS customer_total_spent,
    ps.total_available,
    ps.avg_supply_cost,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_detail
FROM 
    RankedOrders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartStats ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    CustomerSummary cs ON c.c_custkey = cs.c_custkey
WHERE 
    ps.total_available > 0 
    AND (cs.total_orders IS NULL OR cs.total_spent > 1000)
ORDER BY 
    region, nation, order_total_price DESC;
