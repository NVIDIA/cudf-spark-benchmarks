WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
MaxRevenue AS (
    SELECT 
        MAX(net_revenue) AS max_net_revenue 
    FROM 
        OrderDetails
)
SELECT 
    ss.s_name,
    ss.total_supply_cost,
    od.o_orderkey,
    od.o_orderdate,
    od.net_revenue,
    od.item_count
FROM 
    SupplierSummary ss
LEFT JOIN 
    OrderDetails od ON ss.part_count = od.item_count
JOIN 
    MaxRevenue mr ON od.net_revenue = mr.max_net_revenue
WHERE 
    ss.total_supply_cost IS NOT NULL
ORDER BY 
    ss.total_supply_cost DESC, od.net_revenue DESC;