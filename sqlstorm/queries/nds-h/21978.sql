
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1998-01-01'
), SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS supplier_order
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), OrderLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        SUM(CASE 
            WHEN li.l_returnflag = 'R' THEN li.l_quantity 
            ELSE 0 END) AS total_returns
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        li.l_orderkey
), OuterJoinSupplier AS (
    SELECT 
        spd.s_suppkey,
        spd.p_partkey,
        spd.p_name,
        spd.ps_availqty,
        spd.total_supply_value,
        COALESCE(ol.total_revenue, 0) AS total_revenue,
        COALESCE(ol.total_returns, 0) AS total_returns
    FROM 
        SupplierPartDetails spd
    LEFT JOIN 
        OrderLineItems ol ON spd.s_suppkey = ol.l_orderkey
    WHERE 
        spd.ps_availqty > 0
), FilteredData AS (
    SELECT 
        o.o_orderkey,
        oa.s_suppkey,
        oa.total_supply_value,
        RANK() OVER (ORDER BY oa.total_supply_value DESC) AS supply_value_rank
    FROM 
        RankedOrders o
    JOIN 
        OuterJoinSupplier oa ON o.o_orderkey = oa.s_suppkey
    WHERE 
        oa.total_supply_value > (SELECT AVG(total_supply_value) FROM OuterJoinSupplier)
)
SELECT 
    fd.o_orderkey,
    fd.s_suppkey,
    fd.total_supply_value,
    CASE 
        WHEN fd.supply_value_rank <= 10 THEN 'Top Supplier'
        WHEN fd.supply_value_rank <= 20 THEN 'Above Average Supplier'
        ELSE 'Lower Tier Supplier'
    END AS supplier_category,
    CONCAT('Order Key: ', fd.o_orderkey, ' Supplier Key: ', fd.s_suppkey) AS order_supplier_info
FROM 
    FilteredData fd
UNION ALL
SELECT 
    NULL AS o_orderkey,
    n.n_nationkey AS s_suppkey,
    SUM(n.n_nationkey) AS total_supply_value,
    'N/A' AS supplier_category,
    CONCAT('Nation Key: ', n.n_nationkey) AS order_supplier_info
FROM 
    nation n 
GROUP BY 
    n.n_nationkey
ORDER BY 
    total_supply_value DESC;
