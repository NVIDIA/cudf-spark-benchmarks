WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
OrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.o_orderpriority,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_tax) AS total_tax
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ro.rank <= 10 
    GROUP BY 
        ro.o_orderkey, ro.o_orderstatus, ro.o_totalprice, ro.o_orderdate, ro.o_orderpriority, p.p_name, p.p_brand, p.p_type
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    od.o_totalprice,
    od.o_orderdate,
    od.o_orderpriority,
    od.p_name,
    od.p_brand,
    od.p_type,
    od.total_quantity,
    od.total_extended_price,
    od.total_discount,
    od.total_tax
FROM 
    OrderDetails od
WHERE 
    od.o_orderstatus = 'F'
ORDER BY 
    od.o_totalprice DESC
LIMIT 100;
