WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank,
        c.c_name,
        n.n_name AS NationName
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
            ELSE 'Available'
        END AS Availability
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    o.OrderRank,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    sp.p_name,
    sp.s_name,
    sp.ps_availqty,
    sp.Availability,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalLineItemValue
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails sp ON l.l_partkey = sp.ps_partkey
WHERE 
    o.OrderRank <= 5
GROUP BY 
    o.OrderRank, o.o_orderkey, o.o_orderdate, o.o_totalprice, sp.p_name, sp.s_name, sp.ps_availqty, sp.Availability
ORDER BY 
    o.o_orderdate DESC, o.o_orderkey;