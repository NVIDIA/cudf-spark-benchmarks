WITH RegionalStats AS (
    SELECT 
        r.r_name AS region_name,
        SUM(p.p_retailprice * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rs.region_name,
    co.customer_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_orderpriority,
    ol.order_value,
    ol.item_count,
    rs.total_value,
    rs.supplier_count
FROM 
    RegionalStats rs
JOIN 
    CustomerOrders co ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
JOIN 
    OrderLineItems ol ON ol.o_orderkey = co.o_orderkey
ORDER BY 
    rs.region_name, co.o_orderdate DESC, ol.order_value DESC;
