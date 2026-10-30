
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
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
OrderLineDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_net_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(COALESCE(ol.total_net_price, 0)) AS total_order_value,
    MAX(s.s_acctbal) AS highest_supplier_balance
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cs ON cs.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders c ON cs.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                  FROM part p 
                                                                  WHERE p.p_size BETWEEN 10 AND 20) 
                                          LIMIT 1)
LEFT JOIN 
    OrderLineDetails ol ON ol.o_orderkey IN (SELECT o.o_orderkey 
                                               FROM orders o 
                                               WHERE o.o_orderstatus = 'F')
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name
HAVING 
    SUM(COALESCE(ol.total_net_price, 0)) > 100000
ORDER BY 
    customer_count DESC, highest_supplier_balance ASC
