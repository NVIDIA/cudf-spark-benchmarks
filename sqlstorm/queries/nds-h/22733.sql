WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
),

FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue
    FROM lineitem li
    WHERE li.l_returnflag = 'N'
    GROUP BY li.l_orderkey
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        so.total_supplycost,
        CASE 
            WHEN so.total_supplycost > 10000 THEN 'High'
            WHEN so.total_supplycost BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS supply_segment
    FROM RankedOrders o
    JOIN SupplierDetails so ON o.o_orderkey = so.s_suppkey
    WHERE o.rnk = 1
),

FinalOutput AS (
    SELECT 
        h.o_orderkey,
        h.o_totalprice,
        h.supply_segment,
        COALESCE(l.net_revenue, 0) AS net_revenue,
        CASE 
            WHEN l.net_revenue = 0 THEN 'No Revenue'
            ELSE 'Revenue Generated' 
        END AS revenue_status
    FROM HighValueOrders h
    LEFT JOIN FilteredLineItems l ON h.o_orderkey = l.l_orderkey
)

SELECT 
    o.o_orderkey,
    o.o_totalprice,
    o.supply_segment,
    o.net_revenue,
    o.revenue_status
FROM FinalOutput o
WHERE o.supply_segment IS NOT NULL
ORDER BY o.o_totalprice DESC, o.revenue_status, o.o_orderkey
LIMIT 100;