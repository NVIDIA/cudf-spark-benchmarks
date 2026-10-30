WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal,
        c.c_mktsegment,
        c.c_comment
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 10000
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal < 5000
)
SELECT 
    COALESCE(c.nation_name, 'Unknown') AS nation,
    COUNT(DISTINCT co.o_orderkey) AS number_of_orders,
    SUM(co.total_quantity) AS total_items_sold,
    AVG(co.total_extended_price) AS avg_order_value,
    COUNT(DISTINCT sp.p_partkey) AS unique_parts_supplied
FROM 
    RankedOrders co
LEFT JOIN 
    CustomerNation c ON co.o_orderkey = c.c_custkey
LEFT JOIN 
    SupplierPartInfo sp ON sp.s_suppkey = (SELECT MIN(s_suppkey) FROM SupplierPartInfo) 
GROUP BY 
    c.nation_name
ORDER BY 
    total_items_sold DESC
LIMIT 10;