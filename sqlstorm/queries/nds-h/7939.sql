WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.o_shippriority,
        c.c_name,
        n.n_name AS nation_name,
        r.OrderRank
    FROM 
        RankedOrders r
    JOIN 
        customer c ON r.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        r.OrderRank <= 5
),
OrderLineDetails AS (
    SELECT 
        t.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_partkey) AS LineItemCount,
        MAX(l.l_discount) AS MaxDiscount,
        MIN(l.l_discount) AS MinDiscount
    FROM 
        TopOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    t.nation_name,
    SUM(ol.TotalRevenue) AS TotalNationRevenue,
    AVG(ol.LineItemCount) AS AvgLineItemCount,
    MAX(ol.MaxDiscount) AS HighestRecordedDiscount,
    MIN(ol.MinDiscount) AS LowestRecordedDiscount
FROM 
    OrderLineDetails ol
JOIN 
    TopOrders t ON ol.o_orderkey = t.o_orderkey
GROUP BY 
    t.nation_name
ORDER BY 
    TotalNationRevenue DESC;