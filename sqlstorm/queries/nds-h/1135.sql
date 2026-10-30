
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        l.l_suppkey -- Added for JOIN
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-06-01'
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.s_name,
    COALESCE(st.total_supply_cost, 0) AS supply_cost,
    COALESCE(st.total_parts_supplied, 0) AS parts_supplied,
    SUM(f.net_price) AS total_net_price,
    COUNT(f.l_partkey) AS line_item_count
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredLineItems f ON r.o_orderkey = f.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey = f.l_suppkey
LEFT JOIN 
    SupplierStats st ON s.s_suppkey = st.s_suppkey
WHERE 
    r.OrderRank <= 5
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.o_totalprice, s.s_name, st.total_supply_cost, st.total_parts_supplied
ORDER BY 
    r.o_orderdate DESC,
    r.o_totalprice DESC;
