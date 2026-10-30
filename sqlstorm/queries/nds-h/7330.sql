WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
), TopFiveRevenues AS (
    SELECT 
        ro.o_orderkey,
        ro.total_revenue,
        ns.n_name,
        ns.supplier_count,
        ns.total_account_balance
    FROM 
        RankedOrders ro
    JOIN 
        NationSupplier ns ON ro.o_orderstatus = 'F'  
    WHERE 
        ro.revenue_rank <= 5
)
SELECT 
    tfr.o_orderkey,
    tfr.total_revenue,
    tfr.n_name,
    tfr.supplier_count,
    tfr.total_account_balance
FROM 
    TopFiveRevenues tfr
ORDER BY 
    tfr.total_revenue DESC;