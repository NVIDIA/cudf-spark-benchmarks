
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_suppkey,
        li.l_quantity,
        li.l_extendedprice,
        hc.c_name AS high_value_customer,
        rs.s_name AS supplier_name,
        rs.nation_name
    FROM 
        lineitem li
    JOIN 
        HighValueOrders hc ON li.l_orderkey = hc.o_orderkey
    JOIN 
        RankedSuppliers rs ON li.l_suppkey = rs.s_suppkey
    WHERE 
        rs.supplier_rank <= 3
)
SELECT 
    od.l_orderkey,
    od.high_value_customer,
    SUM(od.l_quantity) AS total_quantity,
    SUM(od.l_extendedprice) AS total_extended_price,
    od.nation_name
FROM 
    OrderDetails od
GROUP BY 
    od.l_orderkey, od.high_value_customer, od.nation_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;
