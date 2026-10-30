
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_totalprice,
        r.o_orderdate
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalResult AS (
    SELECT 
        c.c_name,
        COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
        p.p_name,
        CASE 
            WHEN MAX(si.total_supply_cost) IS NULL THEN 'No Supplier Info'
            ELSE CAST(MAX(si.total_supply_cost) AS STRING)
        END AS max_supplier_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem lo ON o.o_orderkey = lo.l_orderkey
    LEFT JOIN 
        PartDetails p ON p.p_partkey = lo.l_partkey
    LEFT JOIN 
        SupplierInfo si ON si.s_suppkey = lo.l_suppkey
    GROUP BY 
        c.c_name, p.p_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 0 AND SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
)
SELECT 
    fr.c_name,
    fr.total_revenue,
    fr.p_name,
    fr.max_supplier_cost,
    CAST(fr.order_count AS STRING) || ' orders' AS order_summary
FROM 
    FinalResult fr
WHERE 
    fr.total_revenue > (
        SELECT 
            AVG(total_revenue) 
        FROM 
            (SELECT 
                COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue
             FROM 
                lineitem lo
             JOIN 
                orders o ON o.o_orderkey = lo.l_orderkey
             GROUP BY 
                o.o_orderkey) AS subquery
    )
ORDER BY 
    fr.total_revenue DESC;
