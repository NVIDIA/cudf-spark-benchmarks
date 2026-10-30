WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'O')
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_size,
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
        ps.ps_availqty > 100
),
OrderLineAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        SUM(ola.total_revenue) AS total_revenue,
        SUM(spi.ps_supplycost * spi.ps_availqty) AS total_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier sp ON n.n_nationkey = sp.s_nationkey
    LEFT JOIN 
        SupplierPartInfo spi ON sp.s_suppkey = spi.s_suppkey
    LEFT JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderLineAggregates ola ON o.o_orderkey = ola.l_orderkey
    WHERE 
        r.r_name LIKE 'N%'
    GROUP BY 
        r.r_name
)
SELECT 
    fr.r_name,
    fr.unique_customers,
    fr.total_revenue,
    fr.total_supply_cost,
    CASE 
        WHEN fr.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(fr.total_revenue AS STRING)
    END AS revenue_status
FROM 
    FinalReport fr
ORDER BY 
    fr.total_revenue DESC NULLS LAST;