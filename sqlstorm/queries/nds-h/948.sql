WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
AggregateSupplier AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        li.l_shipdate,
        CASE 
            WHEN li.l_returnflag = 'R' THEN 'Returned' 
            ELSE 'Not Returned' 
        END AS ReturnStatus
    FROM 
        lineitem li
    WHERE 
        li.l_discount > 0.1 AND li.l_shipdate < cast('1998-10-01' as date)
),
MaxPartSize AS (
    SELECT 
        p.p_partkey,
        MAX(p.p_size) AS MaxSize
    FROM 
        part p
    GROUP BY 
        p.p_partkey
)
SELECT 
    ro.o_orderkey,
    ro.o_totalprice,
    ro.o_orderdate,
    li.l_partkey,
    li.l_quantity,
    li.l_extendedprice,
    li.l_discount,
    asupp.s_name,
    asupp.TotalCost,
    mps.MaxSize
FROM 
    RankedOrders ro
LEFT JOIN 
    FilteredLineItems li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN 
    AggregateSupplier asupp ON li.l_partkey = asupp.ps_partkey
LEFT JOIN 
    MaxPartSize mps ON li.l_partkey = mps.p_partkey 
WHERE 
    ro.OrderRank = 1 
    AND ro.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    ro.o_orderdate DESC, asupp.TotalCost DESC;