WITH SupplierCosts AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        l.l_returnflag
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
)
SELECT 
    n.n_name AS nation_name,
    SUM(ld.net_price) AS total_net_sales,
    COUNT(DISTINCT co.c_custkey) AS distinct_customers,
    AVG(co.total_spent) AS average_spent_per_customer
FROM 
    LineItemDetails ld
JOIN 
    orders o ON ld.l_orderkey = o.o_orderkey
JOIN 
    CustomerOrders co ON o.o_custkey = co.c_custkey
JOIN 
    supplier s ON ld.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
WHERE 
    ld.l_returnflag = 'N'
GROUP BY 
    n.n_name
HAVING 
    SUM(ld.net_price) > (SELECT AVG(total_net_sales) FROM (SELECT SUM(ld.net_price) AS total_net_sales FROM LineItemDetails ld GROUP BY ld.l_partkey) AS avg_sales)
ORDER BY 
    total_net_sales DESC;