
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
),
CombinedData AS (
    SELECT 
        p.p_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        l.l_quantity,
        l.l_discount,
        o.o_orderkey,
        (l.l_extendedprice * (1 - l.l_discount)) AS extended_price
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
        AND (l.l_discount BETWEEN 0.05 AND 0.1 OR l.l_discount IS NULL)
)
SELECT 
    cd.p_name,
    cd.nation_name,
    COUNT(DISTINCT cd.supplier_name) AS unique_suppliers,
    SUM(cd.extended_price) AS total_revenue,
    MAX(r.order_rank) AS max_rank
FROM 
    CombinedData cd
LEFT JOIN 
    RankedOrders r ON cd.o_orderkey = r.o_orderkey
GROUP BY 
    cd.p_name, cd.nation_name
HAVING 
    COUNT(DISTINCT cd.supplier_name) > 5 
    AND SUM(cd.extended_price) > (SELECT AVG(total_revenue) FROM 
                                    (SELECT 
                                        SUM((l.l_extendedprice * (1 - l.l_discount))) AS total_revenue
                                    FROM 
                                        lineitem l
                                    JOIN 
                                        orders o ON l.l_orderkey = o.o_orderkey
                                    WHERE 
                                        o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
                                    GROUP BY 
                                        o.o_orderkey) AS avg_revenue)
ORDER BY 
    total_revenue DESC;
