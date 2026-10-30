
WITH NationAggregates AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        n.n_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, EXTRACT(YEAR FROM o.o_orderdate)
)
SELECT 
    na.nation_name,
    p.p_name,
    p.ps_availqty,
    p.ps_supplycost,
    o.order_year,
    SUM(o.total_revenue) AS annual_revenue,
    na.supplier_count,
    na.total_account_balance
FROM 
    PartSupplierDetails p
JOIN 
    OrderSummary o ON p.p_partkey = o.o_orderkey 
JOIN 
    NationAggregates na ON p.n_name = na.nation_name
GROUP BY 
    na.nation_name, p.p_name, p.ps_availqty, p.ps_supplycost, o.order_year, na.supplier_count, na.total_account_balance
ORDER BY 
    annual_revenue DESC, na.supplier_count DESC
LIMIT 10;
