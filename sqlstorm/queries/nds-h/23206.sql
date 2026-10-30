
WITH RegionalCost AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerActivity AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity_purchased
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.region_name,
    COALESCE(hvo.total_order_value, 0) AS high_value_order_total,
    ca.order_count,
    ca.total_quantity_purchased,
    CASE 
        WHEN ca.total_quantity_purchased IS NULL THEN 'No Purchases'
        WHEN ca.order_count = 0 THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    RegionalCost r
LEFT JOIN 
    HighValueOrders hvo ON r.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RegionalCost)
LEFT JOIN 
    CustomerActivity ca ON ca.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_acctbal IS NOT NULL)
ORDER BY 
    r.region_name, 
    hvo.total_order_value DESC NULLS LAST;
