WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(l.l_orderkey) AS TotalItems
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
        AND (l.l_returnflag = 'R' OR l.l_linestatus = 'F')
    GROUP BY
        o.o_orderkey
),
RankedOrders AS (
    SELECT
        od.o_orderkey,
        od.TotalSales,
        od.TotalItems,
        RANK() OVER (ORDER BY od.TotalSales DESC) AS SalesRank
    FROM
        OrderDetails od
)
SELECT
    s.s_name,
    ss.TotalSupplyCost,
    ro.TotalSales,
    ro.TotalItems,
    ro.SalesRank
FROM
    SupplierStats ss
LEFT JOIN
    RankedOrders ro ON ss.UniqueParts > 5
JOIN
    supplier s ON ss.s_suppkey = s.s_suppkey
WHERE
    (ro.TotalSales IS NOT NULL AND ro.TotalItems > 0)
    OR ss.TotalSupplyCost > 10000
ORDER BY
    ss.TotalSupplyCost DESC, ro.TotalSales DESC;