WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
CustomerOrders AS (
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
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(coalesce(total_orders, 0)) AS total_orders,
    SUM(coalesce(total_spent, 0)) AS total_spent,
    COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rank <= 5)
LEFT JOIN 
    LineItemAggregates la ON la.l_orderkey IN (SELECT o_orderkey 
                                                  FROM orders 
                                                  WHERE o_orderstatus = 'F')
WHERE 
    n.n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
GROUP BY 
    n.n_name
ORDER BY 
    num_customers DESC, total_spent DESC
LIMIT 10;